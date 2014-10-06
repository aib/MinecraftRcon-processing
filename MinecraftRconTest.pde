MinecraftRcon mcr;

void setup()
{
  mcr = new MinecraftRcon("192.168.1.3", 25575, "iskele");

  boolean loggedIn = mcr.login();
  println("Logged in? " + (loggedIn ? "yes" : "no"));

  String response = mcr.sendCommand("list");
  println("Response: " + response);
}

void draw()
{
}

