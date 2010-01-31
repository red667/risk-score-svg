#! /usr/bin/ruby1.9.1
# encoding = utf-8

require 'cairo'
include Math

def cairo_image_surface(name,w,h,bg=nil)
    surface = Cairo::SVGSurface.new(name,w,h)
    image = Cairo::Context.new(surface)
    if bg
	image.set_source_rgba(*bg)
	image.paint
    end
    yield(image)
end

def polyline image, points
    first = true
    points.each do |xy|
	if first
	    image.move_to(*xy)
	    first = false
	else
	    image.line_to(*xy)
	end	
    end
    image.close_path
    first = true
end

def scale image, parts, line
    polyline(image,line)
    #normalvektor
    norm = line.last[0].abs + line.last[1].abs
    nv = line.last.reverse.map {|x| x / norm}
    nv[0] *= -1
    (1..parts).each do |i|
	a = line.last.map {|x| x / parts * i}
	b = a.dup
	2.times do |j| 
	    #first point
	    a[j] += nv[j] * 25
	    #second point
	    b[j] -= nv[j] * 25
	end
	polyline(image,[a, b])
    end
end

w = 3500
h = 4500
r = 1300
lw = 10

red    = [1.0,0.0,0.0,1]
black  = [0.0,0.0,0.0,1]
white  = [1.0,1.0,1.0,1]
yellow = [1.0,0.6,0.0,1]
grey   = [0.5,0.5,0.5,1]
green  = [0.0,1.0,0.0,1]

vars = ["V","E","S","H","Z"]
agenda = ["V .. Verbreitung","E .. Einfachheit","S .. Schadenspotenzial","H .. Häufigkeit","Z .. Zeitaufwand" ]
score = Array.new
filename = ""

if ARGV.length <= 4
    puts "Usage: risk-score-cairo.rb V E S H Z"
    puts "Where V,E,S,H,Z are values from 1..10"
    puts "float are values allowed"
    Process.exit
end

ARGV.each_index do |i|
    score << ARGV[i].to_f
    filename << "%02f" % ARGV[i].to_f
    filename << "-" if i <= 3
end

pentagon_points = Array.new
score_points = Array.new
(1..5).each do |n|
    pentagon_points << [r * sin((2*PI/5)*n) ,
	(-1) * r * cos((2*PI/5)*n)]	# [xn,yn]
    score_points << pentagon_points.last.map {|x| x / 10 * score[n-1]}
end 

cairo_image_surface("#{filename}.svg",w,h,white) do |image|
    #basic cairo setup
    image.set_line_join(Cairo::LINE_JOIN_ROUND)
    image.set_line_cap(Cairo::LINE_CAP_ROUND)
    image.translate((w/2)+lw,r+lw+700)
    #gradient
    g = Cairo::RadialPattern.new(0,0,0,0,0,r)
    g.add_color_stop_rgba(0.2,0.0,1.0,0.0,1)
    g.add_color_stop_rgba(0.5,1.0,1.0,0.0,1)
    g.add_color_stop_rgba(1,1.0,0.0,0.0,1)
    #pentagon
    polyline(image,pentagon_points)
    image.set_source(black)               
    image.set_line_width(lw)
    image.stroke_preserve
    image.set_source(grey)
    image.set_line_width(0)
    image.fill
    #score-points
    polyline(image,score_points)
    image.set_source(black)
    image.set_line_width(lw)
    image.stroke_preserve
    image.set_source(g)
    image.set_line_width(0)
    image.fill
    #scale
    pentagon_points.each do |i|
	scale(image,10,[[0,0],i])
    end
    image.set_source(black)
    image.set_line_width(lw)
    image.stroke
    #score-values
    image.select_font_face("Arial", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_BOLD)
    image.set_font_size(150.0)
    pentagon_points.each_index do |i|
	text = "#{vars[i]} = #{score[i]}"
	extents = image.text_extents(text)
	x = (pentagon_points[i][0] * 1.15) - (extents.width/2 + extents.x_bearing)
	y = (pentagon_points[i][1] * 1.15) - (extents.height/2 + extents.y_bearing)
	image.move_to(x,y)
	image.set_source(black)
	image.set_line_width(1)
	image.text_path(text)
	image.fill_preserve
	image.stroke
    end
    #score-value
    image.set_font_size(250.0)
    text = "Riskscore = #{rs = score.inject(&:+) / 5.00 }"
    extents = image.text_extents(text)
    x = 0 -(extents.width/2 + extents.x_bearing)
    y = -h/2 + 550
    image.move_to(x,y)
    if rs >= 8
	image.set_source(red)
    elsif rs >= 5
	image.set_source(yellow)
    else
	image.set_source(green)
    end
    image.set_line_width(1)
    image.text_path(text)
    image.fill_preserve
    image.stroke
    #agenda
    x += 420
    y += 3300
    image.move_to(x, y)
    image.set_font_size(100)
    image.set_source(black)
    image.set_line_width(1)
    agenda.each do |a|
	text = a
	image.text_path(text)
	image.fill_preserve
	image.stroke
	y += 150
	image.move_to(x, y)
    end
    #image.target.write_to_png("#{filename} .png")
    #puts "Wrote: #{filename} .png"
end
puts "Wrote: " + filename + ".svg"
