defmodule MyApp.Payroll.Employee do
  use Ash.Resource, data_layer: AshPostgres.DataLayer

  postgres do
    table "employee"
    repo MyApp.Repo
  end

  actions do
    defaults([:read, :update, :destroy])

    read :read_all do
      prepare build(load: [:department], sort: [:employee_id])
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :employee_id, :string, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :position, :string, allow_nil?: false
    attribute :start_date, :date, allow_nil?: false
    attribute :end_date, :date, allow_nil?: true
    attribute :salary, :decimal, allow_nil?: true
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  actions do
    create :create do
      primary? true
      argument :department_id, :uuid, allow_nil?: false
      change manage_relationship(:department_id, :department, type: :append_and_remove)
    end
  end

  relationships do
    belongs_to :department, MyApp.Payroll.Department do
      allow_nil? false
    end
  end

  code_interface do
    define_for MyApp.Payroll
    define :create
    define :read_all
  end
end
