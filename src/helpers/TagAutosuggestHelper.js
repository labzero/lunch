import React from 'react';

function escapeRegexCharacters(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/gi, '\\$&');
}

export function generateTagList(allTags, addedTags, autosuggestValue) {
  const escapedValue = escapeRegexCharacters(autosuggestValue.trim());
  const regex = new RegExp(`${escapedValue}`, 'i');
  return allTags
    .filter(tag => addedTags.indexOf(tag.id) === -1)
    .filter(tag => regex.test(tag.name))
    .slice(0, 10);
}

export function getSuggestionValue(suggestion) {
  return suggestion.name;
}

export function renderSuggestion(suggestion) {
  return <span>{suggestion.name}</span>;
}
