import {
  useState,
  useEffect,
  Dispatch,
  SetStateAction,
  useCallback,
} from "react";
import { useDebounceCallback } from "usehooks-ts";

interface InputField {
  id: string;
  title: string;
  placeholder: string;
}

interface InputURLProps {
  title: string;
  value: string;
  onChange: (value: string) => void;
  onPaste: (value: string) => void;
  placeholder: string;
  error?: string;
  isChecking?: boolean;
}

interface DynamicSequentialInputsProps {
  inputFields?: InputField[];
  onSubmit?: (isAllValidated: boolean) => void;
  inputValues: Record<string, string>;
  setInputValues: Dispatch<SetStateAction<Record<string, string>>>;
}

const InputURL: React.FC<InputURLProps> = ({
  title,
  value,
  onChange,
  onPaste,
  placeholder,
  error,
  isChecking,
}) => {
  return (
    <div className="flex flex-col gap-1">
      <p className="!text-black">{title}</p>
      <input
        type="text"
        value={value || ""}
        onChange={(e) => onChange(e.target.value)}
        onPaste={(e) => {
          e.preventDefault();
          const pastedText = e.clipboardData.getData("text");
          onPaste(pastedText);
        }}
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
> = ({ inputFields = [], onSubmit, inputValues, setInputValues }) => {
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [checking, setChecking] = useState<{ [key: string]: boolean }>({});
  const [validatedInputs, setValidatedInputs] = useState<{
    [key: string]: boolean;
  }>({});

  const validateUrl = (url: string): boolean => {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  };

  const checkAllInputsValidated = (): boolean => {
    return inputFields.every((field) => {
      const value = inputValues[field.id]?.trim();
      if (!value) return false;

      return (
        validateUrl(value) &&
        validatedInputs[field.id] &&
        !checking[field.id] &&
        !errors[field.id]
      );
    });
  };

  useEffect(() => {
    const allValidated = checkAllInputsValidated();
    onSubmit?.(allValidated);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [validatedInputs, errors, checking, inputValues]);

  const validateAndUpdateInput = useCallback(
    async (id: string, value: string, title: string): Promise<void> => {
      setErrors((prev) => ({ ...prev, [id]: "" }));
      setValidatedInputs((prev) => ({ ...prev, [id]: false }));
      if (value.trim()) {
        setChecking((prev) => ({ ...prev, [id]: true }));
        try {
          const isValid = validateUrl(value);
          if (!isValid) {
            setErrors((prev) => ({
              ...prev,
              [id]: "<ERROR> Invalid URL",
            }));
            setValidatedInputs((prev) => ({ ...prev, [id]: false }));
          } else {
            setErrors((prev) => ({ ...prev, [id]: "" }));
            setValidatedInputs((prev) => ({ ...prev, [id]: true }));
          }
        } finally {
          setChecking((prev) => ({ ...prev, [id]: false }));
        }
      } else {
        setValidatedInputs((prev) => ({ ...prev, [id]: false }));
        setErrors((prev) => ({ ...prev, [id]: "" }));
      }
    },
    [],
  );
  const debounced = useDebounceCallback(validateAndUpdateInput, 500);

  const handleInputChange = (
    id: string,
    value: string,
    title: string,
  ): void => {
    setInputValues((prev) => ({ ...prev, [id]: value }));
    debounced(id, value, title);
  };

  const handlePaste = (id: string, value: string, title: string): void => {
    setInputValues((prev) => ({ ...prev, [id]: value }));
    validateAndUpdateInput(id, value, title);
  };

  if (!inputFields?.length) return null;

  return (
    <div className="mt-4 pb-8 flex flex-col gap-5">
      {inputFields.map((field) => (
        <InputURL
          key={field.id}
          title={field.title}
          value={inputValues[field.id]}
          onChange={(value) => handleInputChange(field.id, value, field.title)}
          onPaste={(value) => handlePaste(field.id, value, field.title)}
          placeholder={field.placeholder}
          error={errors[field.id]}
          isChecking={checking[field.id]}
        />
      ))}
    </div>
  );
};
