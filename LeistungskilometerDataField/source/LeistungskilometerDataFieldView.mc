using Toybox.WatchUi;
using Toybox.FitContributor as Fit;

class LeistungskilometerDataFieldView extends WatchUi.SimpleDataField {

    const MIN_PER_PKM_FIELD_ID = 0;
    const TOTAL_PKM_FIELD_ID = 1;
    const UNIT = WatchUi.loadResource(Rez.Strings.minPerPkmUnit);

    hidden var minPerPkmField = null;
    hidden var totalPkmField = null;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = UNIT;
        
		minPerPkmField = createField(
            WatchUi.loadResource(Rez.Strings.minPerPkmLong),
            MIN_PER_PKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>UNIT}
        );
        minPerPkmField.setData(0.0);

		totalPkmField = createField(
            WatchUi.loadResource(Rez.Strings.totalPkmLong),
            TOTAL_PKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.totalPkmUnit)}
        );
        totalPkmField.setData(0.0);
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // See Activity.Info in the documentation for available information.
    function compute(info) {
    	if (info == null) {
    		return displayTime(0.0);
    	}
    	
    	if ((greaterZero(info.elapsedDistance) || greaterZero(info.totalAscent))
    		&& greaterZero(info.timerTime)) {
    		var totalPkm = (info.elapsedDistance / 1000) + (info.totalAscent / 100);
	        totalPkmField.setData(totalPkm);
	        
    		var minPerPkm = info.timerTime / (60 * info.elapsedDistance + 600 * info.totalAscent);
	        minPerPkmField.setData(minPerPkm);
    		return displayTime(minPerPkm);
    	}
    	
        return displayTime(0.0);
    }
    
    function greaterZero(value) {
    	return value != null && value > 0.0;
    }
    
    function displayTime(value) {
    	var fullMinutes = Math.floor(value);
    	var fraction = value - fullMinutes;
    	var seconds = Math.round(fraction * 60);
    	return fullMinutes.format("%d") + ":" + seconds.format("%02d");
    }

}