var webpack = require("webpack");
var merge = require("webpack-merge");
var CopyWebpackPlugin = require("copy-webpack-plugin");
var ExtractTextPlugin = require("extract-text-webpack-plugin");


var common = {
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [/node_modules/],
        use: "babel-loader",
      },
      {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract({fallbackLoader: "style-loader", loader:"css-loader"})
      },
      {
        test: /\.scss$/,
        use: [
          "style-loader",
          "css-loader",
          "sass-loader"
        ]
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
              "cwd": __dirname + "/web/elm"
            }
          }
        ]
      },
    ],
    noParse: [/\.elm$/]
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin({
      compress: {warnings: false},
      output: {comments: false}
    })
  ]
};

module.exports = [
  merge(common, {
    entry: [
      "normalize.css",
      "purecss/build/pure.css",
      "font-awesome-loader",
      "./web/static/app/app.scss",
      "./web/static/app/app.js"
    ],
    output: {
      path: "./priv/static",
      filename: "js/app.js"
    },
    resolve: {
      modules: [
        "node_modules",
        __dirname + "/web/static/app"
      ]
    },
    plugins: [
      new CopyWebpackPlugin([{ from: "./web/static/assets" }]),
      new ExtractTextPlugin("css/app.css")
    ]
  })
];
