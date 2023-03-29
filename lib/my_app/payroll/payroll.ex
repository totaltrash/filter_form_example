defmodule MyApp.Payroll do
  use Ash.Api

  resources do
    registry MyApp.Payroll.Registry
  end
end
