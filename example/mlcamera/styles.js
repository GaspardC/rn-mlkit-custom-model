
import {Dimensions, StyleSheet} from 'react-native';

const width = Dimensions.get("window").width;
export default  styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: "column",
    backgroundColor: "white",
    overflow: "hidden"
  },
  containerCamera: {
    width,
    height: width,
    flexDirection: "column",
    backgroundColor: "white",
    overflow: "hidden"
  },
  preview: {
    width,
    height: width,
    justifyContent: "flex-end",
    alignItems: "center"
  },
  capture: {
    flex: 0,
    borderColor: "black",
    borderWidth: 1,
    backgroundColor: "#fff",
    borderRadius: 5,
    padding: 15,
    paddingHorizontal: 20,
    alignSelf: "center",
    margin: 20
  },
  center: { flex: 0, flexDirection: "row", justifyContent: "center" , paddingHorizontal: 20}
});
