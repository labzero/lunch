import React from "react";
import { Tag } from "../interfaces";

function escapeRegexCharacters(str: string) {
  return str.replace(/[.*+?^${}()|[\]\\]/gi, "\\$&");
}

export function generateTagList(
  allTags: Tag[],
  addedTags: number[],
  autosuggestValue: string
) {
  const escapedValue = escapeRegexCharacters(autosuggestValue.trim());
  const regex = new RegExp(`${escapedValue}`, "i");
  return allTags
    .filter((tag) => addedTags.indexOf(tag.id) === -1)
    .filter((tag) => regex.test(tag.name))
    .slice(0, 10);
}

export function getSuggestionValue(suggestion: Tag) {
  return suggestion.name;
}

export function renderSuggestion(suggestion: Tag) {
  return <span>{suggestion.name}</span>;
}
