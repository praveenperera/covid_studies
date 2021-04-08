defmodule Covid do
  def lancet do
    "./inputs/lancet.json"
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
    |> Enum.map(fn study ->
      %{
        cohort1: hd(study.cohort1),
        cohort2: hd(study.cohort2),
        disorders:
          study.outcomes
          |> Enum.map(&disorder/1)
          |> Enum.sort_by(fn x -> x.difference end)
          |> Enum.reverse()
      }
    end)
  end

  @spec output_csvs(any) :: :ok
  def output_csvs(lancet) do
    Enum.each(lancet, &to_csv_each/1)
  end

  defp to_csv_each(condition) do
    File.mkdir_p("./output/lancet")

    file_name = "./output/lancet/#{condition.cohort1} vs #{condition.cohort2}.csv"

    disorders = condition.disorders

    header_row = [
      "Disorder",
      condition.cohort1,
      condition.cohort2,
      "Difference",
      "CHI Squared",
      "P",
      "df"
    ]

    rows =
      disorders
      |> Enum.map(fn d ->
        [d.name, d.cohort1, d.cohort2, d.difference, d.chi2, d.p, d.df]
      end)

    table_data = [header_row | rows]

    file = File.open!(file_name, [:write, :utf8])

    table_data
    |> CSV.encode()
    |> Enum.each(&IO.write(file, &1))
  end

  defp disorder(outcome) do
    cohort1 = Enum.at(outcome[:KM].endSurvivals, 0)
    cohort2 = Enum.at(outcome[:KM].endSurvivals, 1)

    %{
      name: hd(outcome.name),
      cohort1: incidence_percent(cohort1),
      cohort2: incidence_percent(cohort2),
      difference: (incidence(cohort1) - incidence(cohort2)) |> to_percent(),
      chi2: outcome[:KM][:Chi2] |> hd(),
      p: outcome[:KM][:p] |> hd(),
      df: outcome[:KM][:df] |> hd()
    }
  end

  defp incidence(survival), do: 1 - survival

  defp incidence_percent(survival) do
    survival
    |> incidence()
    |> to_percent()
  end

  def to_percent(number) do
    number =
      (number * 100)
      |> Float.round(4)

    "#{number}%"
  end
end
