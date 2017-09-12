defmodule Mix.Tasks.Docs.RepairLinks do
  use Mix.Task

  @shortdoc "Repairs links in generated HTML files"

  def run([]) do
    IO.puts("Expected argument: path to ex_doc HTML output")
  end

  def run(path) do
    # Allow spaces in the path:
    path
    |> Enum.join(" ")
    |> do_run
  end

  def do_run(doc_output_path) do
    IO.inspect(doc_output_path, label: "ex_doc output path")
    # Relative links for files in doc/ are okay; we only need to fix the
    # links found in top-level (markdown) files.
    for fname <- Path.wildcard("./*.md") do
      html_path =
        Path.join([
          doc_output_path,
          Path.basename(fname, ".md") <> ".html"
        ])

      IO.puts("processing #{html_path}")

      content =
        File.read!(html_path)
        |> fix_links

      File.write!(html_path, content)
    end
  end

  defp fix_links(raw_html) do
    anchor_links =
      raw_html
      |> Floki.find("a")
      |> Floki.attribute("href")

    img_links =
      raw_html
      |> Floki.find("img")
      |> Floki.attribute("src")

    bad_links =
      (anchor_links ++ img_links)
      |> Enum.reject(&String.starts_with?(&1, "http://"))
      |> Enum.reject(&String.starts_with?(&1, "https://"))
      |> Enum.reject(&String.starts_with?(&1, "#"))

    new_html =
      bad_links
      |> Enum.reduce(raw_html, fn bad_link, acc ->
           good_link = repair_link(bad_link)
           IO.puts("repaired link: #{bad_link} => #{good_link}")
           acc
           |> String.replace(~s(href="#{bad_link}"), ~s(href="#{good_link}"))
           |> String.replace(~s(src="#{bad_link}"), ~s(src="#{good_link}"))
         end)

    new_html
  end

  defp repair_link("LICENSE") do
    # not very proud of this.
    "../LICENSE"
  end
  defp repair_link(link) do
    toplevel_file? = not String.contains?(link, "/")

    link =
      case toplevel_file? do
        true -> link
        false -> Path.join("..", link)
      end

    link =
      case Path.extname(link) do
        # ".md" -> String.replace_suffix(link, ".md", ".html")
        ".md" -> Path.basename(link, ".md") <> ".html"
        _ -> link
      end

    link
  end
end