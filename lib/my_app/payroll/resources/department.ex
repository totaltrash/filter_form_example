defmodule MyApp.Payroll.Department do
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  postgres do
    table "department"
    repo MyApp.Repo
  end

  actions do
    defaults([:create, :read, :update, :destroy])
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :employees, MyApp.Payroll.Employee do
      destination_attribute :department_id
    end
  end

  code_interface do
    define_for MyApp.Payroll
    define :create, args: [:name]
  end
end
