defmodule TemplateModuleNameTest do
  use ExUnit.Case, async: true

  import TemplateModuleName
  doctest TemplateModuleName

  test "Need add test" do
    assert true == false
  end
end
