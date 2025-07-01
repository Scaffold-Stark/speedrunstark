const fetchFromApi = async ({
  path,
  method,
  body,
}: {
  path: string;
  method: string;
  body?: object;
}) => {
  try {
    const response = await fetch(path, {
      method,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();

    if (!response.ok) {
      // Throw an error with the message from the API response
      const errorMessage = data?.error || `HTTP ${response.status} error`;
      const error = new Error(errorMessage);
      (error as any).status = response.status;
      throw error;
    }

    return data;
  } catch (error: any) {
    // If it's already our custom error, re-throw it
    if (error.status) {
      throw error;
    }
    // For network errors, throw a generic network error
    console.error("Network Error:", error);
    throw new Error("Network error: Unable to connect to server");
  }
};

export const addToIPFS = (yourJSON: object) =>
  fetchFromApi({ path: "/api/ipfs/add", method: "Post", body: yourJSON });

export const getMetadataFromIPFS = (ipfsHash: string) =>
  fetchFromApi({
    path: "/api/ipfs/get-metadata",
    method: "Post",
    body: { ipfsHash },
  });
