defmodule LivebookWeb.SessionLive.SecretsComponent do
  use LivebookWeb, :live_component

  alias Livebook.Hubs
  alias Livebook.Secrets
  alias Livebook.Secrets.Secret
  alias Livebook.Session

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(hubs: Livebook.Hubs.get_hubs([:secrets]))

    {:ok, assign(socket, prefill_assigns(socket))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl flex flex-col space-y-5">
      <h3 class="text-2xl font-semibold text-gray-800">
        <%= @title %>
      </h3>
      <.grant_access_message
        :if={@grant_access_name}
        secret_name={@grant_access_name}
        secret_origin={@grant_access_origin}
        target={@myself}
      />
      <div class="flex flex-columns gap-4">
        <div :if={@select_secret_ref} class="basis-1/2 grow-0 pr-4 border-r">
          <div class="flex flex-col space-y-4">
            <p class="text-gray-800">
              Choose a secret
            </p>
            <div class="flex flex-wrap">
              <.secret_with_badge
                :for={{secret_name, _} <- Enum.sort(@secrets)}
                secret_name={secret_name}
                secret_origin="session"
                stored="Session"
                action="select_secret"
                active={secret_name == @prefill_secret_name}
                target={@myself}
              />
              <.secret_with_badge
                :for={secret <- @saved_secrets}
                secret_name={secret.name}
                secret_store={store(secret)}
                secret_origin={origin(secret)}
                stored={stored(secret)}
                action="select_secret"
                active={false}
                target={@myself}
              />
              <div
                :if={@secrets == %{} and @saved_secrets == []}
                class="w-full text-center text-gray-400 border rounded-lg p-8"
              >
                <.remix_icon icon="folder-lock-line" class="align-middle text-2xl" />
                <span class="mt-1 block text-sm text-gray-700">
                  Secrets not found. <br /> Add to see them here.
                </span>
              </div>
            </div>
          </div>
        </div>
        <.form
          :let={f}
          for={@changeset}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          autocomplete="off"
          class="basis-1/2 grow"
        >
          <div class="flex flex-col space-y-4">
            <p :if={@select_secret_ref} class="text-gray-700">
              Add new secret
            </p>
            <.text_field
              field={f[:name]}
              label="Name (alphanumeric and underscore)"
              autofocus={not @has_prefill}
              spellcheck="false"
              autocomplete="off"
              phx-debounce="blur"
            />
            <.text_field
              field={f[:value]}
              label="Value"
              autofocus={@has_prefill}
              spellcheck="false"
              autocomplete="off"
              phx-debounce="blur"
            />
            <.radio_field
              field={f[:origin]}
              label="Storage"
              options={
                [{"session", "only this session"}, {"app", "in the Livebook app"}] ++
                  if Livebook.Config.feature_flag_enabled?(:hub) do
                    for hub <- @hubs, do: {"hub-#{hub.id}", "in #{hub.hub_emoji} #{hub.hub_name}"}
                  else
                    []
                  end
              }
            />
            <div class="flex space-x-2">
              <button class="button-base button-blue" type="submit" disabled={f.errors != []}>
                <.remix_icon icon="add-line" class="align-middle" />
                <span class="font-normal">Add</span>
              </button>
              <.link patch={@return_to} class="button-base button-outlined-gray">
                Cancel
              </.link>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp secret_with_badge(%{secret_store: "hub"} = assigns) do
    ~H"""
    <div
      role="button"
      class={[
        "flex justify-between w-full font-mono text-sm p-2 border-b cursor-pointer",
        if @active do
          "bg-blue-100 text-blue-700"
        else
          "text-gray-700 hover:bg-gray-100"
        end
      ]}
      phx-value-name={@secret_name}
      phx-value-origin={"hub-" <> @secret_origin}
      phx-target={@target}
      phx-click={@action}
    >
      <%= @secret_name %>
      <span class={[
        "inline-flex items-center font-sans rounded-full px-2.5 py-0.5 text-xs font-medium bg-gray-100",
        if @active do
          "bg-indigo-100 text-blue-800"
        else
          "bg-gray-100 text-gray-800"
        end
      ]}>
        <svg
          :if={@active}
          class="-ml-0.5 mr-1.5 h-2 w-2 text-blue-400"
          fill="currentColor"
          viewBox="0 0 8 8"
        >
          <circle cx="4" cy="4" r="3" />
        </svg>
        <%= @stored %>
      </span>
    </div>
    """
  end

  defp secret_with_badge(assigns) do
    ~H"""
    <div
      role="button"
      class={[
        "flex justify-between w-full font-mono text-sm p-2 border-b cursor-pointer",
        if @active do
          "bg-blue-100 text-blue-700"
        else
          "text-gray-700 hover:bg-gray-100"
        end
      ]}
      phx-value-name={@secret_name}
      phx-value-origin={@secret_store}
      phx-target={@target}
      phx-click={@action}
    >
      <%= @secret_name %>
      <span class={[
        "inline-flex items-center font-sans rounded-full px-2.5 py-0.5 text-xs font-medium bg-gray-100",
        if @active do
          "bg-indigo-100 text-blue-800"
        else
          "bg-gray-100 text-gray-800"
        end
      ]}>
        <svg
          :if={@active}
          class="-ml-0.5 mr-1.5 h-2 w-2 text-blue-400"
          fill="currentColor"
          viewBox="0 0 8 8"
        >
          <circle cx="4" cy="4" r="3" />
        </svg>
        <%= @stored %>
      </span>
    </div>
    """
  end

  defp grant_access_message(assigns) do
    ~H"""
    <div>
      <div class="mx-auto">
        <div class="rounded-lg bg-blue-600 py-1 px-4 shadow-sm">
          <div class="flex flex-wrap items-center justify-between">
            <div class="flex w-0 flex-1 items-center">
              <.remix_icon
                icon="error-warning-fill"
                class="align-middle text-2xl flex text-gray-100 rounded-lg py-2"
              />
              <%= if @secret_origin in ["app", "startup"] do %>
                <span class="ml-2 text-sm font-normal text-gray-100">
                  There is a secret named
                  <span class="font-semibold text-white"><%= @secret_name %></span>
                  in your Livebook app. Allow this session to access it?
                </span>
              <% else %>
                <span class="ml-2 text-sm font-normal text-gray-100">
                  There is a secret named
                  <span class="font-semibold text-white"><%= @secret_name %></span>
                  in your Livebook Hub. Allow this session to access it?
                </span>
              <% end %>
            </div>
            <%= if @secret_origin in ["app", "startup"] do %>
              <button
                class="button-base button-gray"
                phx-click="grant_access"
                phx-value-name={@secret_name}
                phx-value-origin={@secret_origin}
                phx-target={@target}
              >
                Grant access
              </button>
            <% else %>
              <button
                class="button-base button-gray"
                phx-click="grant_access"
                phx-value-name={@secret_name}
                phx-value-origin={"hub-" <> @secret_origin}
                phx-target={@target}
              >
                Grant access
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp prefill_assigns(socket) do
    secret_name = socket.assigns[:prefill_secret_name]
    attrs = %{name: secret_name, value: nil, origin: "session"}

    assigns = %{
      changeset: Secrets.change_secret(%Secret{}, attrs),
      title: title(socket),
      grant_access_name: nil,
      grant_access_origin: "app",
      has_prefill: !is_nil(secret_name)
    }

    case Enum.find(socket.assigns.saved_secrets, &(&1.name == secret_name)) do
      %Secret{name: name, origin: {:hub, id}} ->
        %{assigns | grant_access_name: name, grant_access_origin: id}

      %Secret{name: name, origin: origin} ->
        %{assigns | grant_access_name: name, grant_access_origin: to_string(origin)}

      nil ->
        assigns
    end
  end

  defp store(%{origin: {:hub, _id}}), do: "hub"
  defp store(%{origin: origin}), do: to_string(origin)

  defp origin(%{origin: {:hub, id}}), do: id
  defp origin(%{origin: origin}), do: to_string(origin)

  defp stored(%{origin: {:hub, _}}), do: "Hub"
  defp stored(%{origin: origin}) when origin in [:app, :startup], do: "Livebook"

  @impl true
  def handle_event("save", %{"secret" => attrs}, socket) do
    with {:ok, secret} <- Secrets.validate_secret(build_attrs(attrs)),
         :ok <- set_secret(socket, secret) do
      {:noreply,
       socket
       |> push_patch(to: socket.assigns.return_to)
       |> push_secret_selected(secret.name)}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("select_secret", %{"name" => secret_name} = attrs, socket) do
    grant_access(socket.assigns.saved_secrets, secret_name, build_origin(attrs), socket)

    {:noreply,
     socket
     |> push_patch(to: socket.assigns.return_to)
     |> push_secret_selected(secret_name)}
  end

  def handle_event("validate", %{"secret" => attrs}, socket) do
    {:noreply, assign(socket, changeset: Secrets.change_secret(%Secret{}, build_attrs(attrs)))}
  end

  def handle_event("grant_access", %{"name" => secret_name} = attrs, socket) do
    grant_access(socket.assigns.saved_secrets, secret_name, build_origin(attrs), socket)

    {:noreply,
     socket
     |> push_patch(to: socket.assigns.return_to)
     |> push_secret_selected(secret_name)}
  end

  defp push_secret_selected(%{assigns: %{select_secret_ref: nil}} = socket, _), do: socket

  defp push_secret_selected(%{assigns: %{select_secret_ref: ref}} = socket, secret_name) do
    push_event(socket, "secret_selected", %{select_secret_ref: ref, secret_name: secret_name})
  end

  defp title(%{assigns: %{select_secret_ref: nil}}), do: "Add secret"
  defp title(%{assigns: %{select_secret_options: %{"title" => title}}}), do: title
  defp title(_), do: "Select secret"

  defp build_origin(%{"origin" => "hub-" <> id}), do: {:hub, id}
  defp build_origin(%{"origin" => store}), do: String.to_existing_atom(store)

  defp build_attrs(%{"name" => name, "value" => value} = attrs) do
    %{name: name, value: value, origin: build_origin(attrs)}
  end

  defp set_secret(socket, %Secret{origin: :session} = secret) do
    Session.set_secret(socket.assigns.session.pid, secret)
  end

  defp set_secret(socket, %Secret{origin: :app} = secret) do
    Secrets.set_secret(secret)
    Session.set_secret(socket.assigns.session.pid, secret)
  end

  defp set_secret(socket, %Secret{origin: {:hub, id}} = secret) when is_binary(id) do
    with :ok <- Hubs.create_secret(secret) do
      Session.set_secret(socket.assigns.session.pid, secret)
    end
  end

  defp grant_access(secrets, secret_name, origin, socket) do
    secret = Enum.find(secrets, &(&1.name == secret_name and &1.origin == origin))

    if secret, do: Livebook.Session.set_secret(socket.assigns.session.pid, secret)
  end
end
