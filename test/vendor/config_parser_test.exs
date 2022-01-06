# note(itay): configparser_ex package is required for ex_aws to extract the configuration from ~/.aws/credentials
# add this test as a guard against removing the package
defmodule Vendor.ConfigParserTest do
  use ExUnit.Case

  describe "ConfigParser" do
    test "parse_string/1" do
      result = ConfigParser.parse_string("[default]\naws_blah=1\naws_moshe=5")
      assert result == {:ok, %{"default" => %{"aws_blah" => "1", "aws_moshe" => "5"}}}
    end
  end
end
