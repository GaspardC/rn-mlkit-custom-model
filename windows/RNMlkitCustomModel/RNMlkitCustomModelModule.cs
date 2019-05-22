using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Mlkit.Custom.Model.RNMlkitCustomModel
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNMlkitCustomModelModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNMlkitCustomModelModule"/>.
        /// </summary>
        internal RNMlkitCustomModelModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNMlkitCustomModel";
            }
        }
    }
}
