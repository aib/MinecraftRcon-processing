MinecraftRcon mcr;

void setup()
{
  mcr = new MinecraftRcon("localhost", 25575, "password");

  boolean loggedIn = mcr.login();
  println("Logged in? " + (loggedIn ? "yes" : "no"));

  String response = mcr.sendCommand("list");
  println("Response: " + response);
}

void draw()
{
}

