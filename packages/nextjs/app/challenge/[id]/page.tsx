"use client";

import React, { useEffect, useState } from "react";
import ReactMarkdown from "react-markdown";
import { useParams } from "next/navigation";
import { getMarkdownComponents } from "~~/components/GetMarkdownComponents/GetMarkdownComponents";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";

// eslint-disable-next-line react/display-name

const PageView: React.FC = () => {
  const { id } = useParams();
  const [markdown, setMarkdown] = useState<string>();

  useEffect(() => {
    const getMarkdown = async () => {
      const response = await fetch(
        `https://raw.githubusercontent.com/Scaffold-Stark/speedrunstark/${id}/README.md`,
      );
      let markdownData = await response.text();

      const baseUrl = `https://raw.githubusercontent.com/Scaffold-Stark/speedrunstark/${id}/`;
      markdownData = markdownData.replace(
        /!\[(.*?)\]\((?!https?)(.*?)\)/g,
        `![$1](${baseUrl}$2)`,
      );

      setMarkdown(markdownData);
    };

    getMarkdown();
  }, [id]);

  const handleClick = () => {
    window.open(
      `https://github.com/Scaffold-Stark/speedrunstark/tree/${id}`,
      "_blank",
    );
  };
  return (
    <div className=" flex items-center w-full justify-center sm:text-[12px] ">
      <div className="max-w-[860px] py-20 sm:w-full sm:py-5 sm:px-5 ">
        <ReactMarkdown components={getMarkdownComponents()}>
          {markdown}
        </ReactMarkdown>
        <div className="w-full flex justify-center">
          <button
            className="rounded-full border py-2 px-3 font-medium hover:bg-secondary-content flex items-center justify-center gap-1 text-center"
            onClick={handleClick}
          >
            View it on Github <ArrowTopRightOnSquareIcon className="w-[20px]" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default PageView;
