"use client";

import { lazy, useEffect, useState } from "react";
import type { NextPage } from "next";
import { notification } from "~~/utils/scaffold-stark/notification";
import { addToIPFS } from "~~/utils/simpleNFT/ipfs-fetch";
import nftsMetadata from "~~/utils/simpleNFT/nftsMetadata";
import { INITIAL_ATTEMPT, MAX_ATTEMPTS } from "~~/utils/simpleNFT/constants";

const LazyReactJson = lazy(() => import("react-json-view"));

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
          <LazyReactJson
            style={{ padding: "1rem", borderRadius: "0.75rem" }}
            src={yourJSON}
            theme="solarized"
            enableClipboard={false}
            onEdit={(edit) => {
              setYourJSON(edit.updated_src);
            }}
            onAdd={(add) => {
              setYourJSON(add.updated_src);
            }}
            onDelete={(del) => {
              setYourJSON(del.updated_src);
            }}
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
