defmodule MyAppWeb.FilterFormLive do
  use MyAppWeb, :live_view

  alias MyApp.Payroll.Employee
  alias AshPhoenix.FilterForm

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Employees
      <:actions>
        <.button :if={!@filter_form} phx-click="add_filter" type="button">Add Filter</.button>
      </:actions>
    </.header>
    <.simple_form
      :let={filter_form}
      :if={@filter_form}
      for={@filter_form}
      phx-change="filter_validate"
      phx-submit="filter_submit"
    >
      <.filter_form_component component={filter_form} />
      <:actions>
        <.button>Submit</.button>
      </:actions>
    </.simple_form>
    <.table id="employees" rows={@employees}>
      <:col :let={employee} label="ID">
        <%= employee.employee_id %>
      </:col>
      <:col :let={employee} label="Name">
        <%= employee.name %>
      </:col>
      <:col :let={employee} label="Position">
        <%= employee.position %>
      </:col>
      <:col :let={employee} label="Department">
        <%= employee.department.name %>
      </:col>
      <:col :let={employee} label="Salary">
        <.format_salary salary={employee.salary} />
      </:col>
      <:col :let={employee} label="Start Date">
        <%= employee.start_date %>
      </:col>
      <:col :let={employee} label="End Date">
        <%= employee.end_date %>
      </:col>
    </.table>
    """
  end

  attr :component, :map, required: true
  attr :root_group, :boolean, default: true

  defp filter_form_component(%{component: %{source: %FilterForm{}}} = assigns) do
    ~H"""
    <div class="border-gray-50 border-8 p-4 rounded-xl mt-4">
      <div class="flex flex-row justify-between">
        <div class="flex flex-row gap-2 items-center">
          <%= if @root_group, do: "Filter", else: "Group" %>
          <.input type="select" field={@component[:operator]} options={[And: "and", Or: "or"]} />
        </div>
        <div>
          <.button
            phx-click="add_filter_group"
            phx-value-component-id={@component.source.id}
            type="button"
          >
            Add Group
          </.button>
          <.button
            phx-click="add_filter_predicate"
            phx-value-component-id={@component.source.id}
            type="button"
          >
            Add Predicate
          </.button>
          <%= if @root_group do %>
            <.button phx-click="clear_filter" type="button">
              Clear Filter
            </.button>
            <.button phx-click="remove_filter" type="button">
              Remove Filter
            </.button>
          <% else %>
            <.button
              phx-click="remove_filter_component"
              phx-value-component-id={@component.source.id}
              type="button"
            >
              Remove Group
            </.button>
          <% end %>
        </div>
      </div>
      <.inputs_for :let={component} field={@component[:components]}>
        <.filter_form_component component={component} root_group={false} />
      </.inputs_for>
    </div>
    """
  end

  defp filter_form_component(%{component: %{source: %FilterForm.Predicate{}}} = assigns) do
    ~H"""
    <div class="flex flex-row gap-2 mt-4">
      <.input type="select" options={FilterForm.fields(Employee)} field={@component[:field]} />
      <.input type="select" options={FilterForm.predicates(Employee)} field={@component[:operator]} />
      <.input field={@component[:value]} />
      <.button
        phx-click="remove_filter_component"
        phx-value-component-id={@component.source.id}
        type="button"
      >
        Remove
      </.button>
    </div>
    """
  end

  attr :salary, :any, required: true

  defp format_salary(assigns) do
    ~H"""
    $<%= Decimal.to_string(@salary) %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:filter_form, nil)
      |> assign(:employees, get_employees())

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_validate", %{"filter" => params}, socket) do
    {:noreply,
     assign(socket,
       filter_form: FilterForm.validate(socket.assigns.filter_form, params)
     )}
  end

  def handle_event("filter_submit", %{"filter" => params}, socket) do
    filter_form = FilterForm.validate(socket.assigns.filter_form, params)
    filter = FilterForm.filter(Employee, filter_form)

    case filter do
      {:ok, query} ->
        {:noreply,
         socket
         |> assign(:employees, get_employees(query))
         |> assign(:filter_form, filter_form)}

      {:error, filter_form} ->
        {:noreply, assign(socket, filter_form: filter_form)}
    end
  end

  def handle_event("remove_filter_component", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form: FilterForm.remove_component(socket.assigns.filter_form, component_id)
     )}
  end

  def handle_event("add_filter_group", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form: FilterForm.add_group(socket.assigns.filter_form, to: component_id)
     )}
  end

  def handle_event("add_filter_predicate", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form:
         FilterForm.add_predicate(socket.assigns.filter_form, :name, :contains, nil,
           to: component_id
         )
     )}
  end

  def handle_event("add_filter", _, socket) do
    {:noreply, assign(socket, filter_form: build_filter_form())}
  end

  def handle_event("remove_filter", _, socket) do
    {:noreply, assign(socket, filter_form: nil, employees: get_employees())}
  end

  def handle_event("clear_filter", _, socket) do
    {:noreply, assign(socket, filter_form: build_filter_form(), employees: get_employees())}
  end

  defp build_filter_form() do
    Employee
    |> FilterForm.new()
    |> FilterForm.add_predicate(:name, :contains, nil)
  end

  defp get_employees(query \\ nil), do: Employee.read_all!(query: query)
end
