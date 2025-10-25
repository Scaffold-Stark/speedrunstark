import {
  getNFTMetadataFromIPFS,
  InvalidJSONError,
} from "~~/utils/simpleNFT/ipfs";

export async function POST(request: Request) {
  try {
    const { ipfsHash } = await request.json();

    const validation = validateIpfsHash(ipfsHash);

    if (!validation.valid) {
      return Response.json({ error: validation.error }, { status: 400 });
    }

    const res = await getNFTMetadataFromIPFS(ipfsHash);

    if (res === null) {
      return Response.json({ error: "IPFS hash not found" }, { status: 404 });
    }

    return Response.json(res, { status: 200 });
  } catch (error: any) {
    console.log("Error getting metadata from ipfs", error);

    // Handle InvalidJSONError specifically
    if (error instanceof InvalidJSONError) {
      return Response.json({ error: error.message }, { status: 400 });
    }

    // Handle different types of errors
    if (
      error?.message?.includes("timeout") ||
      error?.message?.includes("network")
    ) {
      return Response.json(
        { error: "Network timeout or connection error" },
        { status: 503 },
      );
    }

    if (
      error?.message?.includes("not found") ||
      error?.message?.includes("404")
    ) {
      return Response.json({ error: "IPFS hash not found" }, { status: 404 });
    }

    // Generic server error for unexpected cases
    return Response.json(
      { error: "Internal server error while fetching metadata" },
      { status: 500 },
    );
  }
}

function validateIpfsHash(ipfsHash: string) {
  if (!ipfsHash || typeof ipfsHash !== "string") {
    return {
      valid: false,
      error: "Invalid input: ipfsHash is required and must be a string",
    };
  }

  // Basic IPFS hash format validation (should be alphanumeric and reasonable length)
  if (
    !/^[A-Za-z0-9]+$/.test(ipfsHash) ||
    ipfsHash.length < 10 ||
    ipfsHash.length > 100
  ) {
    return {
      valid: false,
      error: "Invalid IPFS hash format",
    };
  }

  return {
    valid: true,
    error: null,
  };
}
