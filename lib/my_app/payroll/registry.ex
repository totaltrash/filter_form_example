defmodule MyApp.Payroll.Registry do
  use Ash.Registry,
    extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry MyApp.Payroll.Employee
    entry MyApp.Payroll.Department
  end
end
