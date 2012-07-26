# Convert image to ascii art
# Todo:
#   Convert image to text
#   Retain colours
#   Retain shading
#   Retain size
#
# Howto:
#   Width/char_width Height/char_height = Columns + Rows

require 'RMagick'
require 'open-uri'
require 'base64'
require 'paint'
include Magick

# Takes array of pixels, returns RGB colour
def get_average_colour pixels
    temp = Image.new(5,5)
    temp.import_pixels(0, 0, 5, 5, "RGB", pixels)

    # From StackOverflow http://stackoverflow.com/a/5163356
    total = 0
    avg = { :r => 0.0, :g => 0.0, :b => 0.0 }
    temp.color_histogram.each { |c, n|
        avg[:r] += n * c.red
        avg[:g] += n * c.green
        avg[:b] += n * c.blue
        total += n
    }
    [:r, :g, :b].each { |comp| avg[comp] /= total }
    return avg
end

def get_bw_char colour
    gray = colour[:r]
    if gray > 250
        return " "
    elsif gray > 230
        return "."
    elsif gray > 200
        return ":"
    elsif gray > 190
        return "c"
    elsif gray > 170
        return "o"
    elsif gray > 140
        return "C"
    elsif gray > 100
        return "O"
    elsif gray > 50
        return "8"
    end
    
    return "@"
end

def store_image colours, x, y
    puts "X: #{x}, Y: #{y}"
    @new_image.store_pixels(x, y, 1, 1, colours)
end

def save_image image_name, pixel_size
    @new_image.scale!(pixel_size)
    @new_image.write(image_name)    
end

def read_image image_data, colour_mode
    puts "Reading image data"
    image = Image.read_inline(image_data).first
    #image.change_geometry!('250x250') { |cols, rows, img|
    #    img.resize!(cols, rows)
    #}
    gray_image = image.quantize(256, Magick::GRAYColorspace) 
    size = {:width => image.columns, :height => image.rows}
    
    # Every nth pixel
    psw = 4
    psh = 8
    #@new_image = Image.new(size[:width]/ps+1, size[:height]/ps+1)
    image_string = ""
    pixel_char = "@"
    for y in 0..size[:height]/psh
        for x in 0..size[:width]/psw
            c = get_average_colour image.export_pixels_to_str(x*psw, y*psh, psw, psh) if colour_mode != "bw"
            bw = get_average_colour gray_image.export_pixels_to_str(x*psw, y*psh, psw, psh)
            # store_image [Pixel.new(c[:r], c[:g], c[:b], 0)], x, y
            pixel_char = get_bw_char(bw)
            c = bw if colour_mode == "bw"

            image_string = image_string + Paint[pixel_char, [c[:r], c[:g], c[:b]]]
        end
        puts image_string
        image_string = ""
    end
#    save_image "final.jpg", ps
end


if ARGV.empty?
    puts "Usage: #{$PROGRAM_NAME} <input file/address> <bw | color (default)>"
elsif !File.exist? ARGV[0]
    image_data = open ARGV[0], &:read
else
    image_data = File.read ARGV[0]
end

if ARGV[1] == "bw"
    color_mode = "bw"
else
    color_mode =" color"
end

read_image Base64.encode64(image_data), color_mode if image_data
