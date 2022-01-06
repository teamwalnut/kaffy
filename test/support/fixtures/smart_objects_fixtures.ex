defmodule Api.Storylines.SmartObjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Storylines.SmartObjects` context.
  """

  @text_edit %{
    "cssSelector" => "div > .newText",
    "frameSelectors" => ["iframe"],
    "domSelector" => %{
      "xpathNode" => "div > a",
      "xpathFrames" => ["xpath iframe"]
    },
    "lastEditedAt" => "2021-02-21T15:44:56.868Z",
    "kind" => "TEXT",
    "textEditProps" => %{
      "originalText" => "original text",
      "text" => "new text"
    }
  }

  @bind_edit %{
    "domSelector" => %{"xpathFrames" => [], "xpathNode" => "div"},
    "frameSelectors" => ["iframe"],
    "cssSelector" => ".bind",
    "kind" => "BINDING",
    "lastEditedAt" => "2021-02-21T15:44:56.868Z",
    "bindingEditProps" => %{
      "program" =>
        "{\"@astVersion\":\"Ast_20210525\",\"@envVersion\":\"Env_20210525\",\"@expression\":{\"@args\":[{\"@name\":\"name\",\"@value\":\"name test\"},{\"@name\":\"defaultValue\",\"@value\":\"updated default value\"},{\"@name\":\"description\",\"@value\":\"updated desc\"}],\"@fnName\":\"PUBLIC_FIELD\",\"@id\":\"ef44f562-1d5e-4d38-bf59-7ef7a402380d\",\"@type\":\"Call\"}}",
      "originalText" => "original dom element"
    }
  }

  @style_edit %{
    "cssSelector" => "div > .newStyle",
    "frameSelectors" => ["iframe"],
    "domSelector" => %{
      "xpathNode" => "div > a",
      "xpathFrames" => ["xpath iframe"]
    },
    "lastEditedAt" => "2021-02-21T15:44:56.868Z",
    "kind" => "STYLE",
    "styleEditProps" => %{
      "underline" => true,
      "bold" => true,
      "hide" => true,
      "font_size" => "10px",
      "color" => "#ffffff"
    }
  }

  @edit_empty_css_selector %{
    "frameSelectors" => ["iframe"],
    "cssSelector" => "",
    "lastEditedAt" => "2021-02-21T15:44:56.868Z",
    "kind" => "TEXT",
    "textEditProps" => %{
      "originalText" => "original text",
      "text" => "this is going to fail"
    }
  }

  @one_pixel_png "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII="

  @smart_object_class %{
    "name" => "my smart object class",
    "thumbnail" => @one_pixel_png,
    "edits" => [@style_edit, @text_edit],
    "domSelector" => %{
      "xpathNode" => "div > a",
      "xpathFrames" => ["xpath iframe"]
    },
    "frameSelectors" => ["iframe"],
    "cssSelector" => "body"
  }

  @smart_object_class_empty_edit_selector %{
    "name" => "my smart object class",
    "thumbnail" => @one_pixel_png,
    "edits" => [@edit_empty_css_selector],
    "domSelector" => %{
      "xpathNode" => "div > a",
      "xpathFrames" => ["xpath iframe"]
    },
    "frameSelectors" => ["iframe"],
    "cssSelector" => "body"
  }

  def smart_object_class_thumbnail_fixture, do: @one_pixel_png
  def smart_object_class_for_gql_fixture, do: @smart_object_class
  def smart_object_class_empty_edit_selector, do: @smart_object_class_empty_edit_selector
  def smart_object_style_edit_fixture, do: @style_edit
  def smart_object_text_edit_fixture, do: @text_edit
  def smart_object_binding_edit_fixutre, do: @bind_edit

  def smart_object_class_link_edit_fixture(screen_id),
    do: %{
      "css_selector" => "div .newDestinationLink",
      "frame_selectors" => ["iframe"],
      "domSelector" => %{
        "xpathNode" => "div > a",
        "xpathFrames" => ["xpath iframe"]
      },
      "kind" => "link",
      "last_edited_at" => "2021-02-21T15:44:56.868Z",
      "link_edit_props" => %{
        "destination" => %{
          "kind" => "screen",
          "id" => screen_id,
          "delay_ms" => nil
        }
      }
    }
end
