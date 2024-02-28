using System.Windows.Forms; // Make sure to include the necessary namespaces

public class LoadingWindow : Form {
    public LoadingWindow() {
        // Initialize the window and set properties
        this.Text = "Loading";
        this.StartPosition = FormStartPosition.CenterScreen;
        // Add a loading indicator or any other components here
    }
}

// In your MainWindow or wherever you handle the method channel:
channel.setMessageHandler((message) async {
  if (message.method == "showLoadingWindow") {
    Application.Run(new LoadingWindow());
    return null;
  } else if (message.method == "closeLoadingWindow") {
    // Logic to close the loading window
    return null;
  }
  return null;
});
