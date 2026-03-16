import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

async function run() {
  const client = new Client(
    { name: "test", version: "1.0.0" },
    { capabilities: {} }
  );
  
  // Notice we use 'localhost' here, which might be resolving to this strange IPv6 or custom local IP
  const transport = new SSEClientTransport(new URL('http://localhost:8081/mcp'));
  
  try {
    await client.connect(transport);
    console.log("Connected successfully!");
  } catch (e) {
    console.error("Connection failed:", e.message);
    if (e.cause) console.error("Cause:", e.cause);
  } finally {
    await client.close();
  }
}

run();
