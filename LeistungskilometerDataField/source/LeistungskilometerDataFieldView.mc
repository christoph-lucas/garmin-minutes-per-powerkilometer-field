using Toybox.WatchUi;
using Toybox.FitContributor as Fit;
using Toybox.Activity;

class LeistungskilometerDataFieldView extends WatchUi.SimpleDataField {

    enum {
    	TOTAL_PKM,
    	CUR_PKM,
    	AVG_PKM
    }

    const AVERAGE_MIN_PER_PKM_FIELD_ID = 0;
    const CURRENT_MIN_PER_PKM_FIELD_ID = 2;
    const TOTAL_PKM_FIELD_ID = 1;
    
    // TODO provide settings
    hidden var showValueSetting = AVG_PKM;
    hidden var alpha = 0.9;
    
    hidden var averageMinPerPkmField = null;
    hidden var currentMinPerPkmField = null;
    hidden var totalPkmField = null;
    
    hidden var lastDisplayValue = 0.0;
    
    hidden var lastCurrentMinutesPerPkm = null;
    hidden var lastTotalPkm = 0.0;
    hidden var lastTotalTimeInMs = 0;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        // TODO depends on setting
        label = WatchUi.loadResource(Rez.Strings.minPerPkmUnit);
        
		averageMinPerPkmField = createField(
            WatchUi.loadResource(Rez.Strings.avgMinPerPkmLong),
            AVERAGE_MIN_PER_PKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.minPerPkmUnit)}
        );
        averageMinPerPkmField.setData(0.0);

		currentMinPerPkmField = createField(
            WatchUi.loadResource(Rez.Strings.curMinPerPkmLong),
            CURRENT_MIN_PER_PKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_RECORD, :units=>WatchUi.loadResource(Rez.Strings.minPerPkmUnit)}
        );
        currentMinPerPkmField.setData(0.0);

		totalPkmField = createField(
            WatchUi.loadResource(Rez.Strings.totalPkmLong),
            TOTAL_PKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.pkmUnit)}
        );
        totalPkmField.setData(0.0);
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // See Activity.Info in the documentation for available information.
    function compute(info) {
    	if (info == null || info.timerState != Activity.TIMER_STATE_ON) {
    		return displayTime(lastDisplayValue);
    	}
    	
    	if ((greaterZero(info.elapsedDistance) || greaterZero(info.totalAscent))
    		&& greaterZero(info.timerTime)) {
    		var totalPkm = updateTotalPkm(info);
			var avgMinPerPkm = updateAverageMinutesPerPkm(info);
			var curMinPerPkm = updateCurrentMinutesPerPkm(info, totalPkm);
			
			lastTotalTimeInMs = info.timerTime;
    		lastTotalPkm = totalPkm;
    		
    		switch (showValueSetting) {
    			case AVG_PKM:
    				lastDisplayValue = avgMinPerPkm;
		    		return displayTime(lastDisplayValue);
    			case CUR_PKM:
    				lastDisplayValue = curMinPerPkm;
		    		return displayTime(lastDisplayValue);
    			case TOTAL_PKM:
    				lastDisplayValue = totalPkm;
    				return lastDisplayValue;
    		}
    	}
    	
        return displayTime(lastDisplayValue);
    }

	function updateTotalPkm(info) {
		var totalPkm = (info.elapsedDistance / 1000) + (info.totalAscent / 100);
        totalPkmField.setData(totalPkm);
        return totalPkm;
	}
    
    function updateAverageMinutesPerPkm(info) {
		var avgMinPerPkm = info.timerTime / (60 * info.elapsedDistance + 600 * info.totalAscent);
        averageMinPerPkmField.setData(avgMinPerPkm);
        return avgMinPerPkm;
    }
    
    function updateCurrentMinutesPerPkm(info, totalPkm) {
		var timeDeltaInMs = info.timerTime - lastTotalTimeInMs;
		var timeDeltaInMin = timeDeltaInMs / 60000.0;
		var pkmDelta = totalPkm - lastTotalPkm;
		var curMinPerPkm = timeDeltaInMin / pkmDelta;

		var result = null;
		if (lastCurrentMinutesPerPkm == null) {
			result = curMinPerPkm;
		} else {
			result = (alpha * curMinPerPkm) + ((1-alpha)*lastCurrentMinutesPerPkm);
		}

		lastCurrentMinutesPerPkm = result;
        currentMinPerPkmField.setData(result);
        return result;
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