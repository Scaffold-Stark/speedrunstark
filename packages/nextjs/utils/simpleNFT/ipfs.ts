import { create } from "kubo-rpc-client";

const PROJECT_ID = "2GajDLTC6y04qsYsoDRq9nGmWwK";
const PROJECT_SECRET = "48c62c6b3f82d2ecfa2cbe4c90f97037";
const PROJECT_ID_SECRECT = `${PROJECT_ID}:${PROJECT_SECRET}`;

export const ipfsClient = create({
  host: "ipfs.infura.io",
  port: 5001,
  protocol: "https",
  headers: {
    Authorization: `Basic ${Buffer.from(PROJECT_ID_SECRECT).toString("base64")}`,
  },
});

// Custom error class for invalid JSON content
export class InvalidJSONError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidJSONError";
  }
}

export async function getNFTMetadataFromIPFS(ipfsHash: string) {
  try {
    let fileFound = false;
    for await (const file of ipfsClient.get(ipfsHash)) {
      fileFound = true;
      // The file is of type unit8array so we need to convert it to string
      const content = new TextDecoder().decode(file);
      // Remove any leading/trailing whitespace
      const trimmedContent = content.trim();
      // Find the start and end index of the JSON object
      const startIndex = trimmedContent.indexOf("{");
      const endIndex = trimmedContent.lastIndexOf("}") + 1;

      if (startIndex === -1 || endIndex === 0) {
        console.log("No valid JSON object found in IPFS file");
        throw new InvalidJSONError("No valid JSON object found in IPFS file");
      }

      // Extract the JSON object string
      const jsonObjectString = trimmedContent.slice(startIndex, endIndex);
      try {
        const jsonObject = JSON.parse(jsonObjectString);
        return jsonObject;
      } catch (error) {
        console.log("Error parsing JSON:", error);
        throw new InvalidJSONError("Invalid JSON content in IPFS file");
      }
    }

    // If no files were found in the iterator
    if (!fileFound) {
      return null;
    }
  } catch (error: any) {
    // Re-throw InvalidJSONError as-is
    if (error instanceof InvalidJSONError) {
      throw error;
    }

    console.log("IPFS fetch error:", error);

    // Re-throw network/connection errors so they can be handled appropriately
    if (error?.message?.includes('timeout') ||
      error?.message?.includes('network') ||
      error?.code === 'ENOTFOUND' ||
      error?.code === 'ECONNREFUSED') {
      throw new Error(`Network error: ${error.message}`);
    }

    // Handle 404-like errors from IPFS
    if (error?.message?.includes('not found') ||
      error?.message?.includes('404') ||
      error?.message?.includes('no such file')) {
      return null;
    }

    // Re-throw other unexpected errors
    throw error;
  }
}
