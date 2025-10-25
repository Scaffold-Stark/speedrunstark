"use client";

import { useEffect, useState } from "react";
import type { NextPage } from "next";
import { notification } from "~~/utils/scaffold-stark/notification";
import { getMetadataFromIPFS } from "~~/utils/simpleNFT/ipfs-fetch";
import { INITIAL_ATTEMPT, MAX_ATTEMPTS } from "~~/utils/simpleNFT/constants";

// Import the JSON editor component and its core CSS
import { JsonEditor as Editor } from "jsoneditor-react";

const IpfsDownload: NextPage = () => {
  const [yourJSON, setYourJSON] = useState<object | null>(null);
  const [ipfsPath, setIpfsPath] = useState("");
  const [loading, setLoading] = useState(false);
  const [mounted, setMounted] = useState(false);
  // In your state
  const [editorKey, setEditorKey] = useState(0);
  useEffect(() => {
    setMounted(true);
    console.log("Updated JSON to editor:", yourJSON);
  }, [yourJSON]);

  const handleIpfsDownload = async () => {
    setLoading(true);
    const loadingNotificationId = notification.loading(
      "Getting data from IPFS...",
    );
    let retryNotificationId = null;
    let attempt = INITIAL_ATTEMPT;
    const maxAttempts = MAX_ATTEMPTS;

    while (attempt < maxAttempts) {
      try {
        const metaData = await getMetadataFromIPFS(ipfsPath);

        notification.remove(loadingNotificationId);
        if (retryNotificationId) notification.remove(retryNotificationId);
        notification.success("Downloaded from IPFS");

        // Fix: Ensure it's serializable
        const cleanData = JSON.parse(JSON.stringify(metaData));
        console.log("meta-data:", cleanData);

        setYourJSON(cleanData);
        setEditorKey((prevKey) => prevKey + 1);
        break;
      } catch (error) {
        attempt++;
        if (attempt < maxAttempts) {
          retryNotificationId = notification.info(
            `Retrying download... (${attempt}/${maxAttempts})`,
          );
        } else {
          notification.remove(loadingNotificationId);
          if (retryNotificationId) notification.remove(retryNotificationId);
          notification.error(
            error instanceof Error
              ? error.message
              : "Error downloading from IPFS",
          );
          console.error("IPFS Download Error:", error);
        }
      }
    }

    setLoading(false);
  };

  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <h1 className="text-center mb-4">
        <span className="block text-4xl font-bold">Download from IPFS</span>
      </h1>

      <div
        className={`flex border-2 border-accent/95 bg-base-200 rounded-full text-accent w-96`}
      >
        <input
          className="input input-ghost focus:outline-none focus:bg-transparent focus:text-secondary-content h-[2.2rem] min-h-[2.2rem] px-4 border w-full font-medium placeholder:text-accent/50 text-secondary-content/75"
          placeholder="IPFS CID"
          value={ipfsPath}
          onChange={(e) => setIpfsPath(e.target.value)}
          autoComplete="off"
        />
      </div>

      <button
        className={`btn btn-secondary text-white my-6 ${loading ? "loading" : ""}`}
        disabled={loading}
        onClick={handleIpfsDownload}
      >
        Download from IPFS
      </button>

      {mounted && yourJSON && Object.keys(yourJSON).length > 0 && (
        <div style={{ width: "100%", maxWidth: "1000px" }}>
          <Editor
            key={editorKey} // Add this line
            value={yourJSON}
            onChange={(updatedJson: object) => setYourJSON(updatedJson)}
            mode="tree"
            modes={["tree", "code", "form", "text", "view"]}
            htmlElementProps={{
              style: {
                height: "500px",
                borderRadius: "0.75rem",
                border: "1px solid #ccc",
                overflow: "hidden",
              },
            }}
          />
        </div>
      )}
    </div>
  );
};

export default IpfsDownload;
