var path = require("path");
var webpack = require("webpack");
var merge = require("webpack-merge");
var CopyWebpackPlugin = require("copy-webpack-plugin");
var ExtractTextPlugin = require("extract-text-webpack-plugin");
var StatsWriterPlugin = require("webpack-stats-plugin").StatsWriterPlugin;


var ENV = process.env.ENVIRONMENT || "dev";
var FILENAME = "[name]";

if (ENV === "prod") {
  FILENAME = "[name].[chunkhash]";
}


var common = {
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [/node_modules/],
        use: "babel-loader",
      },
      {
        test: [/\.scss$/, /\.css$/],
        loader: ExtractTextPlugin.extract({
          fallbackLoader: "style-loader",
          loader: "css-loader!sass-loader"
        })
      },
      {
        test: /\.(png|jpg|gif|svg)$/,
        use: "file-loader?name=/images/[name].[ext]"
      },
      {
        test: /\.(ttf|eot|svg|woff2?)$/,
        use: "file-loader?name=/fonts/[name].[ext]",
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: "elm-webpack-loader",
            options: {
              "cwd": path.resolve(__dirname, "web", "elm")
            }
          }
        ]
      },
    ],
    noParse: [/\.elm$/]
  },
  // TODO: run this in prod only
  // plugins: [
  //   new webpack.optimize.UglifyJsPlugin({
  //     compress: {warnings: false},
  //     output: {comments: false}
  //   })
  // ]
};


module.exports = [
  merge(common, {
    entry: {
      vendor: [
        "normalize.css",
        "purecss/build/pure.css",
        "font-awesome-loader",
      ],
      app: [
        "./web/static/app/app.scss",
        "./web/static/app/app.js"
      ]
    },
    output: {
      path: "./priv/static",
      filename: "js/" + FILENAME + ".js"
    },
    resolve: {
      modules: [
        "node_modules",
        path.resolve(__dirname, "web", "static", "app")
      ]
    },
    plugins: [
      new webpack.optimize.CommonsChunkPlugin({
        names: ["vendor", "manifest"]
      }),
      new CopyWebpackPlugin([{ from: "./web/static/assets" }]),
      new ExtractTextPlugin("css/" + FILENAME + ".css"),
      new StatsWriterPlugin()
    ]
  })
];
