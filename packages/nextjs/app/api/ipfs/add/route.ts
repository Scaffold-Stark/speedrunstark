import { ipfsClient } from "~~/utils/simpleNFT/ipfs";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const res = await ipfsClient.add(JSON.stringify(body));
    return Response.json(res, { status: 200 });
  } catch (error) {
    console.log("Error adding to ipfs", error);
    return Response.json({ error: "Error adding to ipfs" }, { status: 500 });
  }
}
