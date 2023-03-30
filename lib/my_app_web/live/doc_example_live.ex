defmodule MyAppWeb.DocExampleLive do
  use MyAppWeb, :live_view

  alias MyApp.Payroll.Employee

  @impl true
  def render(assigns) do
    ~H"""
    <.simple_form
      :let={filter_form}
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
      <:col :let={employee} label="Payroll ID"><%= employee.employee_id %></:col>
      <:col :let={employee} label="Name"><%= employee.name %></:col>
      <:col :let={employee} label="Position"><%= employee.position %></:col>
    </.table>
    """
  end

  # `filter_form_component` lets you build a structure of nested groups and predicates.

  defp filter_form_component(%{component: %{source: %AshPhoenix.FilterForm{}}} = assigns) do
    ~H"""
    <div class="border-gray-50 border-8 p-4 rounded-xl mt-4">
      <div class="flex flex-row justify-between">
        <div class="flex flex-row gap-2 items-center">Filter</div>
        <div class="flex flex-row gap-2 items-center">
          <.input type="select" field={@component[:operator]} options={["and", "or"]} />
          <.button phx-click="add_filter_group" phx-value-component-id={@component.id} type="button">
            Add Group
          </.button>
          <.button
            phx-click="add_filter_predicate"
            phx-value-component-id={@component.id}
            type="button"
          >
            Add Predicate
          </.button>
          <.button
            phx-click="remove_filter_component"
            phx-value-component-id={@component.id}
            type="button"
          >
            Remove Group
          </.button>
        </div>
      </div>
      <.inputs_for :let={component} field={@component[:components]}>
        <.filter_form_component component={component} />
      </.inputs_for>
    </div>
    """
  end

  defp filter_form_component(
         %{component: %{source: %AshPhoenix.FilterForm.Predicate{}}} = assigns
       ) do
    ~H"""
    <div class="flex flex-row gap-2 mt-4">
      <.input
        type="select"
        options={AshPhoenix.FilterForm.fields(Employee)}
        field={@component[:field]}
      />
      <.input
        type="select"
        options={AshPhoenix.FilterForm.predicates(Employee)}
        field={@component[:operator]}
      />
      <.input field={@component[:value]} />
      <.button
        phx-click="remove_filter_component"
        phx-value-component-id={@component.id}
        type="button"
      >
        Remove
      </.button>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:filter_form, AshPhoenix.FilterForm.new(Employee))
      |> assign(:employees, Employee.read_all!())

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_validate", %{"filter" => params}, socket) do
    {:noreply,
     assign(socket,
       filter_form: AshPhoenix.FilterForm.validate(socket.assigns.filter_form, params)
     )}
  end

  def handle_event("filter_submit", %{"filter" => params}, socket) do
    filter_form = AshPhoenix.FilterForm.validate(socket.assigns.filter_form, params)

    IO.inspect(AshPhoenix.FilterForm.to_filter_expression(filter_form))

    case AshPhoenix.FilterForm.filter(Employee, filter_form) do
      {:ok, query} ->
        {:noreply,
         socket
         |> assign(:employees, Employee.read_all!(query: query))
         |> assign(:filter_form, filter_form)}

      {:error, filter_form} ->
        {:noreply, assign(socket, filter_form: filter_form)}
    end
  end

  def handle_event("remove_filter_component", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form:
         AshPhoenix.FilterForm.remove_component(socket.assigns.filter_form, component_id)
     )}
  end

  def handle_event("add_filter_group", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form: AshPhoenix.FilterForm.add_group(socket.assigns.filter_form, to: component_id)
     )}
  end

  def handle_event("add_filter_predicate", %{"component-id" => component_id}, socket) do
    {:noreply,
     assign(socket,
       filter_form:
         AshPhoenix.FilterForm.add_predicate(socket.assigns.filter_form, :name, :contains, nil,
           to: component_id
         )
     )}
  end
end
