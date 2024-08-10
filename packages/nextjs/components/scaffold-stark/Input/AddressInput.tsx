import { useCallback } from "react";
import { blo } from "blo";
import { useDebounceValue } from "usehooks-ts";
import { CommonInputProps, InputBase } from "~~/components/scaffold-stark";
import { Address } from "@starknet-react/chains";
import { getChecksumAddress, validateChecksumAddress } from "starknet";
import { BlockieAvatar } from "~~/components/scaffold-stark/BlockieAvatar";
import { getStarknetPFPIfExists } from "~~/utils/profile";
import useConditionalStarkProfile from "~~/hooks/useConditionalStarkProfile";
/**
 * Address input with ENS name resolution
 */
export const AddressInput = ({
  value,
  name,
  placeholder,
  onChange,
  disabled,
}: CommonInputProps<Address | string>) => {
  const [_debouncedValue] = useDebounceValue(value, 500);
  const handleChange = useCallback(
    (newValue: Address) => {
      onChange(newValue);
    },
    [onChange],
  );

  const isValidAddress = typeof value === "string" && value.startsWith("0x");
  const checkSumAddress = isValidAddress
    ? getChecksumAddress(value as Address)
    : undefined;
  const { data: profile } = useConditionalStarkProfile(value as Address);

  return (
    <InputBase<Address>
      name={name}
      placeholder={placeholder}
      value={value as Address}
      onChange={handleChange}
      disabled={disabled}
      prefix={null}
      suffix={
        //eslint-disable-next-line @next/next/no-img-element
        checkSumAddress &&
        validateChecksumAddress(checkSumAddress) &&
        (getStarknetPFPIfExists(profile?.profilePicture) ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={profile?.profilePicture}
            alt="Profile Picture"
            className="rounded-full"
            width={35}
            height={35}
          />
        ) : (
          <BlockieAvatar address={checkSumAddress} size={35} />
        ))
      }
    />
  );
};
