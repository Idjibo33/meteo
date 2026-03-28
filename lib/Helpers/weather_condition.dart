String getWeatherDescriptionImage(String weather) {
  switch (weather) {
    case "Thunderstorm":
      return "assets/1.png";
    case "Drizzle":
      return "assets/2.png";
    case "Rain":
      return "assets/3.png";
    case "Snow":
      return "assets/4.png";
    case "Atmosphere":
      return "assets/5.png";
    case "Clear":
      return "assets/6.png";
    case "Clouds":
      return "assets/7.png";
    default:
      return "assets/8.png";
  }
}
