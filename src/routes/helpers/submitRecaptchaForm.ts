const submitRecaptchaForm = (
  action: string,
  formData: {
    email: string;
    "g-recaptcha-response": string;
  }
) => {
  const newForm = document.createElement("form");
  newForm.method = "POST";
  newForm.action = action;

  // Add all original form data
  Object.entries(formData).forEach(([key, value]) => {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = key;
    input.value = value;
    newForm.appendChild(input);
  });

  document.body.appendChild(newForm);
  newForm.submit();
  document.body.removeChild(newForm);
};

export default submitRecaptchaForm;
