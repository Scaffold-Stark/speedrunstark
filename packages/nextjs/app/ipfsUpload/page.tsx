"use client";

import { useEffect, useState } from "react"; // Suspense is not needed for direct import
import type { NextPage } from "next";
import { notification } from "~~/utils/scaffold-stark/notification";
import { addToIPFS } from "~~/utils/simpleNFT/ipfs-fetch";
import nftsMetadata from "~~/utils/simpleNFT/nftsMetadata";
import { INITIAL_ATTEMPT, MAX_ATTEMPTS } from "~~/utils/simpleNFT/constants";

// Import the new JSON editor component and its CSS
import { JsonEditor as Editor } from 'jsoneditor-react';
import 'jsoneditor/dist/jsoneditor.min.css'; // This is the correct path for the core jsoneditor CSS

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
          // Using jsoneditor-react
          // 'value' prop holds the JSON data
          // 'onChange' is the callback for when the JSON changes
          // 'mode' can be 'tree', 'code', 'form', 'text', 'view'
          <Editor
            value={yourJSON}
            onChange={(updatedJson: object) => setYourJSON(updatedJson)}
            mode="tree" // Set default mode to 'tree' for an interactive view
            // You can also add more modes to allow users to switch
            // modes={['tree', 'code']}
            // To enable editing in tree mode, you don't need separate onEdit/onAdd/onDelete,
            // as it's built into the mode="tree" functionality by default.
            // You can hide the menu or status bar if desired
            // menu={false}
            // statusBar={false}

            // Custom styling often needs to be done via CSS overrides for jsoneditor
            // The 'style' prop usually applies to the outer container.
            // For internal styling, you might need to target jsoneditor's classes
            htmlElementProps={{ style: { padding: "1rem", borderRadius: "0.75rem", border: "1px solid #ccc", height: '500px' } }}
            // Note: jsoneditor-react often requires a fixed height or Flexbox container
            // for the editor to render correctly. 'height: 500px' is an example.
          />
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