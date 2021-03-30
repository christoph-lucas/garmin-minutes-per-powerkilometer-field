using Toybox.WatchUi;
using Toybox.FitContributor as Fit;

class LeistungskilometerDataFieldView extends WatchUi.SimpleDataField {

    const MIN_PER_LKM_FIELD_ID = 0;
    const TOTAL_LKM_FIELD_ID = 1;
    const UNIT = WatchUi.loadResource(Rez.Strings.minPerPkmShort);

    hidden var minPerLkmField = null;
    hidden var totalLkmField = null;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = UNIT;
        
		minPerLkmField = createField(
            WatchUi.loadResource(Rez.Strings.minPerPkmLong),
            MIN_PER_LKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>UNIT}
        );
        minPerLkmField.setData(0.0);

		totalLkmField = createField(
            WatchUi.loadResource(Rez.Strings.totalPkmLong),
            TOTAL_LKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>"lkm"}
        );
        totalLkmField.setData(0.0);
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // See Activity.Info in the documentation for available information.
    function compute(info) {
    	if (info == null) {
    		return convertToTime(0.0);
    	}
    	
    	if ((greaterZero(info.elapsedDistance) || greaterZero(info.totalAscent))
    		&& greaterZero(info.timerTime)) {
    		var totalLkm = (info.elapsedDistance / 1000) + (info.totalAscent / 100);
	        totalLkmField.setData(info.elapsedDistance);
	        
    		var res = info.timerTime / (60 * info.elapsedDistance + 600 * info.totalAscent);
	        minPerLkmField.setData(res);
    		return convertToTime(res);
    	}
    	
        return convertToTime(0.0);
    }
    
    function greaterZero(value) {
    	return value != null && value > 0.0;
    }
    
    function convertToTime(value) {
    	var fullMinutes = Math.floor(value);
    	var fraction = value - fullMinutes;
    	var seconds = Math.round(fraction * 60);
    	return fullMinutes.format("%d") + ":" + seconds.format("%02d");
    }

	// DEBUG START
	//System.println("");
	//System.println("dist: " + info.elapsedDistance);
	//System.println("ascent: " + info.totalAscent);
	//System.println("time: " + info.timerTime);
	//System.println("speed m/s: " + info.averageSpeed);
	//if (greaterZero(info.averageSpeed)) {
    //	System.println("pace min/km: " + convertToTime(1000.0/(60.0 * info.averageSpeed)));
	//}
	
	//var display = convertToTime(res);
	//System.println("pace min/lkm: " + display);
	//return display;
	
	// DEBUG END

}