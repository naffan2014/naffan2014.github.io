# Title: Simple Image tag for Jekyll
# Authors: Brandon Mathis http://brandonmathis.com
#          Felix Schäfer, Frederic Hemberger
# Description: Easily output images with optional class names, width, height, title and alt attributes
#
# Syntax {% img [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | "title text" ["alt text"]] %}
#
# Examples:
# {% img /images/ninja.png Ninja Attack! %}
# {% img left half http://site.com/images/ninja.png Ninja Attack! %}
# {% img left half http://site.com/images/ninja.png 150 150 "Ninja Attack!" "Ninja in attack posture" %}
#
# Output:
# <img src="/images/ninja.png">
# <img class="left half" src="http://site.com/images/ninja.png" title="Ninja Attack!" alt="Ninja Attack!">
# <img class="left half" src="http://site.com/images/ninja.png" width="150" height="150" title="Ninja Attack!" alt="Ninja in attack posture">
#
module Jekyll

  class ImageTag < Liquid::Tag
    @img = {}

    def initialize(tag_name, markup, tokens)
      # <img class="lazy" src="img/grey.gif" data-original="img/example.jpg" width="640" height="480">

      if markup =~ /(?:(\S+) )?((?:https?:\/\/|\/|\S+\/)\S+)(?:\s+(\d+))?(?:\s+(\d+))?\s+(.*)?/i
        unless $2.nil?
          imgclass = $1 || nil
          image = $2
          width = $3 || nil
          height = $4 || nil
          title = $5 || nil
          @img = {}
          @img["class"] = imgclass ? "lazy #{imgclass}" : "lazy"

          begin
            if image =~ /^(http:\/\/brettterpstra.com|\/)/
              image.sub!(/^(http:\/\/brettterpstra.com)?/,"")
              @img["data-original"] = image
              filename = File.expand_path(File.join(%x{git rev-parse --show-toplevel}.strip,"source"+image))
              @img["width"] = width || filename ? %x{sips -g pixelWidth "#{filename}"|awk '{print $2}'}.strip : nil
              @img["height"] = height || filename ? %x{sips -g pixelHeight "#{filename}"|awk '{print $2}'}.strip : nil
            else
              @img["data-original"] = image
              @img["width"] = width if width
              @img["height"] = height if height
            end
          rescue
            @img["data-original"] = image
            @img["width"] = width if width
            @img["height"] = height if height
          end

          @img["src"] = "/images/default.jpg"
          if title && title !~ /^[\s"]*$/
            if /(?:"|')(?<xtitle>[^"']+)?(?:"|')\s+(?:"|')(?<alt>[^"']+)?(?:"|')/ =~ title
              @img['title']  = xtitle
              @img['alt']    = alt
            else
              @img['alt']    = title.gsub(/(^["\s]*|["\s]*$)/, '')
            end
          end
        end
      end
      super
    end

    def render(context)
      unless @img.empty?
        if context.registers[:site].config["production"]
          @img["src"] = context.registers[:site].config["cdn_url"] + @img["src"]
          if @img["data-original"] =~ /^(http:\/\/brettterpstra.com|\/)/
            @img["data-original"] = context.registers[:site].config["cdn_url"] + @img["data-original"]
          end
        end
        %Q{<img #{@img.collect {|k,v| "#{k}=\"#{v}\"" if v}.join(" ")}>}
      else
        "Error processing input, expected syntax: {% img [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | \"title text\" [\"alt text\"]] %}"
      end
    end
  end
end

Liquid::Template.register_tag('img', Jekyll::ImageTag)