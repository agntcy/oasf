# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.SwaggerXssTest do
  # The :version path segment is echoed into the swagger document, which is
  # embedded inside a <script> block in a text/html response. A version
  # containing "</script>" must not be able to close that block.
  use SchemaWeb.ConnCase, async: false

  @payload "</script><script>alert(1)</script>"
  @block ~r|<script type="application/json" id="swagger-json">(.*?)</script>|s

  test "a version containing a closing script tag cannot break out" do
    path = "/" <> URI.encode(@payload, &URI.char_unreserved?/1) <> "/doc"
    conn = get(build_conn(), path)

    assert conn.status == 200
    body = conn.resp_body

    # Not reflected as markup...
    refute body =~ "</script><script>"

    # ...and the JSON block is still a single element that parses, with the
    # payload preserved as data rather than becoming part of the document.
    assert [_, json] = Regex.run(@block, body)
    assert {:ok, decoded} = Jason.decode(json)
    assert Enum.any?(Map.keys(decoded["paths"]), &String.contains?(&1, @payload))
  end

  test "the default document is still valid JSON" do
    conn = get(build_conn(), "/doc")

    assert conn.status == 200
    assert [_, json] = Regex.run(@block, conn.resp_body)
    assert {:ok, %{"paths" => paths}} = Jason.decode(json)
    assert map_size(paths) > 0
  end
end
