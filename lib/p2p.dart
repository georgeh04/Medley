import 'dart:io';
import 'dart:convert';

void connectAndSend() async {
  // Connect to the server
  final socket = await Socket.connect('localhost', 3000);
  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

  // Send a test message
  String message = 'Hello from Client!';
  print('Client sending: $message');
  socket.add(utf8.encode(message));

  // Listen for responses
  socket.listen((data) {
    print('Server sent: ${utf8.decode(data)}');
    socket.destroy();
  });

  // Wait for the communication to finish
  await Future.delayed(Duration(seconds: 2));
  socket.close();
}

void startServer() async {
  // Bind the server socket to an address and port
  final server =
      await ServerSocket.bind(InternetAddress.anyIPv4, 3000, shared: true);
  print('Server listening on port ${server.port} using ip ${server.address}');

  // Listen for connections
  await for (final client in server) {
    print('Connection from'
        ' ${client.remoteAddress.address}:${client.remotePort}');
    client.listen((data) {
      print('Message from client: ${String.fromCharCodes(data)}');
      // Echo the message back to the client
      client.add(data);
    });
  }
}

void testServerConnection() async {
  try {
    // Attempt to connect to the server
    final socket =
        await Socket.connect('localhost', 3000, timeout: Duration(seconds: 5));
    print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

    // Send a test message
    socket.writeln('Hello, Server!');

    // Listen for responses
    socket.listen(
      (data) {
        print('Server: ${String.fromCharCodes(data)}');
        socket.destroy();
      },
      onError: (error) {
        print('Error: $error');
        socket.destroy();
      },
      onDone: () {
        print('Connection closed.');
      },
    );
  } on SocketException catch (e) {
    print('Failed to connect: $e');
  }
}
