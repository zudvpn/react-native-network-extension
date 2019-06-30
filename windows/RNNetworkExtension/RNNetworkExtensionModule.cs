using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Network.Extension.RNNetworkExtension
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNNetworkExtensionModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNNetworkExtensionModule"/>.
        /// </summary>
        internal RNNetworkExtensionModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNNetworkExtension";
            }
        }
    }
}
