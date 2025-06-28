import { getNFTMetadataFromIPFS } from "~~/utils/simpleNFT/ipfs";

export async function POST(request: Request) {
  try {
    const { ipfsHash } = await request.json();
    const res = await getNFTMetadataFromIPFS(ipfsHash);
    return Response.json(res, { status: 200 });
  } catch (error: any) {
    console.log("Error getting metadata from ipfs", error);

    // Handle different types of errors
    if (error?.message?.includes('timeout') || error?.message?.includes('network')) {
      return Response.json(
        { error: "Network timeout or connection error" },
        { status: 503 },
      );
    }

    if (error?.message?.includes('not found') || error?.message?.includes('404')) {
      return Response.json(
        { error: "IPFS hash not found" },
        { status: 404 },
      );
    }

    // Generic server error for unexpected cases
    return Response.json(
      { error: "Internal server error while fetching metadata" },
      { status: 500 },
    );
  }
}
