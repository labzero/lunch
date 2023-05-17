export default (showPOIs) => ({
  backgroundColor: "#fcb3f2",
  scrollwheel: false,
  styles: [
    {
      featureType: "landscape",
      elementType: "geometry",
      stylers: [
        {
          color: "#fbf5fa",
        },
      ],
    },
    {
      featureType: "road",
      elementType: "geometry",
      stylers: [
        {
          color: "#fdc0cb",
        },
      ],
    },
    {
      featureType: "poi",
      elementType: "geometry.fill",
      stylers: [
        {
          color: "#fbd1f6",
        },
      ],
    },
    {
      featureType: "poi",
      elementType: "labels",
      stylers: [
        {
          visibility: "off",
        },
      ],
    },
    {
      featureType: "poi.business",
      elementType: "labels",
      stylers: [
        {
          visibility: showPOIs ? "on" : "off",
        },
      ],
    },
    {
      featureType: "water",
      elementType: "geometry",
      stylers: [
        {
          color: "#fcb3f2",
        },
      ],
    },
  ],
});
