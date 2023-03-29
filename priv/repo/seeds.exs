# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MyApp.Repo.insert!(%MyApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Original employee sample data from https://www.thespreadsheetguru.com/blog/sample-data
# Build a sample data csv with only the fields we'll be interested in
# file = File.open!("artifacts/sample_data.csv", [:write, :utf8])

# File.stream!("artifacts/original_employee_sample_data.csv")
# |> CSV.decode!()
# |> Enum.map(fn row ->
#   Enum.slice(row, 0..4) ++ Enum.slice(row, 8..9) ++ Enum.slice(row, 11..13)
# end)
# |> CSV.encode()
# |> Enum.each(&IO.write(file, &1))

sample_data =
  File.stream!("artifacts/sample_data.csv")
  |> CSV.decode!()
  |> Enum.drop(901)

department_map =
  sample_data
  |> Enum.map(fn row -> Enum.at(row, 3) end)
  |> Enum.uniq()
  |> Enum.reduce(%{}, fn department_name, acc ->
    %{id: id} = MyApp.Payroll.Department.create!(department_name)
    Map.put(acc, department_name, id)
  end)

format_date = fn date_string ->
  case date_string do
    "" ->
      nil

    date_string ->
      date_parts =
        date_string
        |> String.split("/")
        |> Enum.map(&String.to_integer/1)

      Date.new!(Enum.at(date_parts, 2), Enum.at(date_parts, 0), Enum.at(date_parts, 1))
  end
end

sample_data
|> Enum.each(fn row ->
  MyApp.Payroll.Employee.create!(%{
    employee_id: Enum.at(row, 0),
    name: Enum.at(row, 1),
    position: Enum.at(row, 2),
    start_date: format_date.(Enum.at(row, 5)),
    end_date: format_date.(Enum.at(row, 9)),
    salary: String.replace(Enum.at(row, 6), ~r/\D/, "") <> ".00",
    department_id: Map.get(department_map, Enum.at(row, 3))
  })
end)
