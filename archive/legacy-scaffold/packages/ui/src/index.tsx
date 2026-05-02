import React from "react";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement>;

export function Button(props: ButtonProps) {
  return (
    <button
      {...props}
      style={{
        borderRadius: 8,
        border: "1px solid #0a7f6f",
        background: "#0a7f6f",
        color: "white",
        padding: "8px 14px",
        ...props.style,
      }}
    />
  );
}
