defmodule ApiWeb.DemoController do
  use ApiWeb, :controller

  alias Api.CustomDomains
  alias Api.Storylines.Demos

  def show(conn, %{"demoId" => demo_id}) do
    demo = Demos.get_demo!(demo_id, %{preload: [:company]})
    demo_company_id = demo.company.id

    if demo_company_id |> CustomDomains.demo_domain?(conn.host) do
      query_string = if conn.query_string == "", do: "", else: "?#{conn.query_string}"

      render(conn, "demo.html",
        layout: {ApiWeb.DemoView, "demo.html"},
        page_title: demo.name,
        demo_id: demo_id,
        demo_endpoint: Application.get_env(:api, :app_url),
        query_string: query_string
      )
    else
      conn
      |> put_status(403)
      |> render("demo.html",
        layout: {ApiWeb.DemoView, "demo.html"},
        page_title: "Unauthorized",
        demo_id: "",
        demo_endpoint: Application.get_env(:api, :app_url),
        query_string: ""
      )
    end
  end
end
