"use client";

import { useEffect, useState } from "react";
import type { NextPage } from "next";
import { notification } from "~~/utils/scaffold-stark/notification";
import { addToIPFS } from "~~/utils/simpleNFT/ipfs-fetch";
import nftsMetadata from "~~/utils/simpleNFT/nftsMetadata";
import { INITIAL_ATTEMPT, MAX_ATTEMPTS } from "~~/utils/simpleNFT/constants";

// Import the JSON editor component and its core CSS
import { JsonEditor as Editor } from "jsoneditor-react";

const IpfsUpload: NextPage = () => {
  const [yourJSON, setYourJSON] = useState<object>(nftsMetadata[0]);
  const [loading, setLoading] = useState(false);
  const [uploadedIpfsPath, setUploadedIpfsPath] = useState("");
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleIpfsUpload = async () => {
    setLoading(true);
    const notificationId = notification.loading("Uploading to IPFS...");
    let attempt = INITIAL_ATTEMPT;
    const maxAttempts = MAX_ATTEMPTS;

    while (attempt < maxAttempts) {
      try {
        const uploadedItem = await addToIPFS(yourJSON);
        notification.remove(notificationId);
        notification.success("Uploaded to IPFS");
        setUploadedIpfsPath(uploadedItem.path);
        break;
      } catch (error) {
        attempt++;
        if (attempt < maxAttempts) {
          notification.info(`Retrying upload... (${attempt}/${maxAttempts})`);
        } else {
          notification.remove(notificationId);
          notification.error("Error uploading to IPFS");
          console.error("IPFS Upload Error:", error);
        }
      }
    }
    setLoading(false);
  };

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <h1 className="text-center mb-4">
          <span className="block text-4xl font-bold">Upload to IPFS</span>
        </h1>

        {mounted && (
          <div style={{ width: "100%", maxWidth: "1000px" }}>
            <Editor
              value={yourJSON}
              onChange={(updatedJson: object) => setYourJSON(updatedJson)}
              mode="tree"
              modes={["tree", "code", "form", "text", "view"]}
              htmlElementProps={{
                style: {
                  height: "500px",
                  borderRadius: "0.75rem",
                  border: "1px solid #ccc", // Keep a subtle border for the container
                  overflow: "hidden",
                },
              }}
            />
          </div>
        )}

        <button
          className={`btn btn-secondary text-white my-4 ${loading ? "loading" : ""}`}
          disabled={loading}
          onClick={handleIpfsUpload}
        >
          Upload to IPFS
        </button>

        {uploadedIpfsPath && (
          <div className="mt-4">
            <a
              href={`https://ipfs.io/ipfs/${uploadedIpfsPath}`}
              target="_blank"
              rel="noreferrer"
            >
              {`https://ipfs.io/ipfs/${uploadedIpfsPath}`}
            </a>
          </div>
        )}
      </div>
    </>
  );
};

export default IpfsUpload;
