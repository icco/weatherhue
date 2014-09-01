require "faraday"
require "json"
require "pp"
require "color"

def color_for_temp(temp)
  remainder = temp % 5
  if remainder == 0
    return HSL[temp]
  end

  lower = temp - remainder
  upper = lower + 5

  lower_color = hsl_to_color(HSL[lower])
  upper_color = hsl_to_color(HSL[upper])

  color = lower_color.mix_with(upper_color, remainder / 5.0)

  color_to_hsl color
end

def hsl_to_color(hsl)
  Color::HSL.from_fraction(
    hsl[0] / 65535.0,
    hsl[1] / 255.0,
    hsl[2] / 255.0)
end

def color_to_hsl(color)
  [(color.h * 65535).to_i, (color.s * 255).to_i, (color.l * 255).to_i]
end

HSL = {
  -20=>[53884, 255, 217],
  -15=>[53988, 198, 187],
  -10=>[53726, 161, 167],
  -5=>[52902, 133, 145],
  0=>[50399, 145, 123],
  5=>[48821, 185, 102],
  10=>[44592, 156, 98],
  15=>[39094, 215, 108],
  20=>[36305, 241, 112],
  25=>[35041, 255, 122],
  30=>[31547, 224, 117],
  35=>[22141, 207, 113],
  40=>[19216, 255, 93],
  45=>[16245, 255, 98],
  50=>[13075, 255, 104],
  55=>[11802, 255, 105],
  60=>[10831, 255, 120],
  65=>[9901, 255, 123],
  70=>[8470, 255, 122],
  75=>[5908, 255, 122],
  80=>[3346, 255, 117],
  85=>[2983, 255, 113],
  90=>[2409, 255, 102],
  95=>[1820, 255, 93],
  100=>[1492, 255, 80]
}

if temp = ARGV[0]
  temp = temp.to_i
else
  url = "http://www.myweather2.com/developer/forecast.ashx?uac=#{ENV["WEATHER2_TOKEN"]}&temp_unit=f&output=json&query=#{ENV["WEATHER2_QUERY"]}"
  res = Faraday.get(url)
  if res.status != 200
    puts res.status
    puts res.body
    exit
  end

  data = JSON.parse(res.body)
  temp = data["weather"]["curren_weather"][0]["temp"].to_i
end

temp = [temp, -20].max
temp = [temp, 100].min

temp_color = color_for_temp(temp)

hueapi = Faraday.new ENV["HUE_API"]

state = {
  :on => true,
  :hue => temp_color[0],
  :sat => temp_color[1],
  :bri => temp_color[2],
  :transitiontime => 10,
}

puts temp
puts state.to_json
hueapi.put "/api/#{ENV["HUE_USER"]}/lights/#{ENV["HUE_LIGHT"]}/state", state.to_json
