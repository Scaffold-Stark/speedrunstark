import { useState } from "react";

interface InputField {
  id: string;
  title: string;
  placeholder: string;
}

interface InputURLProps {
  title: string;
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
  error?: string;
  isChecking?: boolean;
}

interface DynamicSequentialInputsProps {
  inputFields: InputField[];
}

const InputURL: React.FC<InputURLProps> = ({
  title,
  value,
  onChange,
  placeholder,
  error,
  isChecking,
}) => {
  return (
    <div className="flex flex-col gap-1">
      <p className="!text-black">{title}</p>
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className={`!text-[#4D58FF] border-none outline-none px-2 bg-transparent caret-[#4D58FF] appearance-none`}
      />
      {isChecking && <p className="!text-gray-500">Checking...</p>}
      {!isChecking && error && <p className="!text-[#FF282C]">{error}</p>}
    </div>
  );
};

export const DynamicSequentialInputs: React.FC<
  DynamicSequentialInputsProps
> = ({ inputFields }) => {
  const [inputValues, setInputValues] = useState<Record<string, string>>(() =>
    inputFields.reduce((acc, field) => ({ ...acc, [field.id]: "" }), {}),
  );
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [checking, setChecking] = useState<{ [key: string]: boolean }>({});
  const [validatedInputs, setValidatedInputs] = useState<{
    [key: string]: boolean;
  }>({});

  const validateUrl = (url: string): boolean => {
    return url.toLowerCase().includes("vercel");
  };

  const handleInputChange = (id: string, value: string): void => {
    setInputValues((prev) => ({ ...prev, [id]: value }));
    setErrors((prev) => ({ ...prev, [id]: "" }));
    setValidatedInputs((prev) => ({ ...prev, [id]: false }));

    if (value.trim()) {
      setChecking((prev) => ({ ...prev, [id]: true }));

      setTimeout(() => {
        const isValid = validateUrl(value);
        if (!isValid) {
          setErrors((prev) => ({
            ...prev,
            [id]: "<ERROR> Invalid URL_Please use vercel URL",
          }));
          setValidatedInputs((prev) => ({ ...prev, [id]: false }));
        } else {
          setValidatedInputs((prev) => ({ ...prev, [id]: true }));
        }
        setChecking((prev) => ({ ...prev, [id]: false }));
      }, 2000);
    }
  };

  const shouldShowInput = (index: number): boolean => {
    if (index === 0) return true;

    const previousInputs = inputFields.slice(0, index);
    return previousInputs.every((field) => {
      const value = inputValues[field.id]?.trim();
      return (
        value &&
        validatedInputs[field.id] &&
        !checking[field.id] &&
        !errors[field.id]
      );
    });
  };

  return (
    <div className="mt-4 pb-8 flex flex-col gap-5">
      {inputFields.map(
        (field, index) =>
          shouldShowInput(index) && (
            <InputURL
              key={field.id}
              title={field.title}
              value={inputValues[field.id]}
              onChange={(value) => handleInputChange(field.id, value)}
              placeholder={field.placeholder}
              error={errors[field.id]}
              isChecking={checking[field.id]}
            />
          ),
      )}
    </div>
  );
};
